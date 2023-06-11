# >>> Insert, edit, remove users
# Copyright 2023 Roland Metivier <metivier.roland@chlorophyt.us>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Exsemantica.Administrate.Users do
  def insert(name, password, biography) do
    case Exsemantica.Handle128.convert_to(name) do
      {:ok, handle} ->
        {:ok,
         Exsemantica.Repo.insert(%Exsemantica.Repo.User{
           name: handle,
           password_hash: Argon2.hash_pwd_salt(password),
           biography: biography
         })}

      error ->
        error
    end
  end
end
